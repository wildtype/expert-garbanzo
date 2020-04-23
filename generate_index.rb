#!/usr/bin/env ruby
require 'json'
require 'csv'

def template(booklist_json)
  <<~HTML.strip
    <html>
      <head>
        <title>Springer free book index</title>
        <style>
          body{ font-family: sans-serif; font-size: 12px; }
          table { border: none; }
          td { padding: .5em; margin: 0; vertical-align: top; }
          td.title { width: 400px; }
          td.sc { font-size: .8em; }
          thead tr { background: black; color: white; font-weight: 700; }
          tbody tr td { border-bottom: 1px solid #ccc; }
          input#q{ border: none; width: 80%; padding: .2em; font-size: 2em; margin:1em 0; }
          input[type="checkbox"] { display: none }
          input[type="checkbox"]:checked + label { background-color: blue; color: white; }
          label { font-size: 2em; padding: .2em; border-radius: 5px; color: blue; text-decoration: underline; cursor: pointer; }
    
          tr.hide { display: none; }
          input[type="checkbox"]:checked ~ table td.misc { display: none; }
          input[type="checkbox"]:checked ~ table td.title { width: 100%; }
          input[type="checkbox"]:checked ~ table { width: 100%; }
        </style>
      </head>
      <body>
        <input id="q" type="text" onblur="this.focus()" autofocus placeholder="Type title, author, or subject then press enter to search" />
        <input type="checkbox" id="toggleMisc" on/>
        <label for="toggleMisc">Show only title</label>
        <table id="index" cellspacing=0>
          <thead>
            <tr>
              <td class="title">Title</td>
              <td class="misc">Author</td>
              <td class="misc">Misc</td>
            </tr>
          </thead>
          <tbody>
          </tbody>
        </table>
        <script>
          let bookIndex = #{booklist_json};
          fillTable(bookIndex);

          let searchInput = document.querySelector('input#q');
          let rows = document.querySelectorAll('table > tbody > tr');

          searchInput.addEventListener('keypress', (event) => { 
            if (event.keyCode == 13) {
              search(event.target.value, rows);
            }
          });

          searchInput.addEventListener('keyup', (event) => { 
            if (event.keyCode == 8 && event.target.value == '') {
              showAll(rows);
            }
          });

          function createRow(item) {
            let haystack = [item.author, item.title, item.subjectClassification, item.seriesTitle].join(' ').toLowerCase();

            return `
              <tr data-haystack="${haystack}">
                <td class="title"><a href="${item.url}">${item.title}</a></td>
                <td class="misc">${item.author}</td>
                <td class="sc misc">
                  Edition: ${item.edition}<br/>
                  Series Title: ${item.seriesTitle}<br/>
                  Volume Number: ${item.volumeNumber}<br/>
                  Subject Classification: ${item.subjectClassification}
                </td>
              </tr>
            `;
          }

          function fillTable(items) {
            let tableBody = items
              .map(item => createRow(item))
              .join("\\n");
            document.querySelector('tbody').innerHTML = tableBody;
          }

          function hideIfNotRelevant(item, query) {
            let words = query.toLowerCase().split(' ');
            let haystack = item.dataset.haystack;
            let founds = words.map(word => haystack.indexOf(word) > -1);

            if (!founds.every(found => found)) {
              item.classList.add('hide');
            }
          }

          function search(query, rows) {
            showAll(rows);
            if (query.length) {
              rows.forEach(item => hideIfNotRelevant(item, query));
            }
          }

          function showAll(rows) {
            rows.forEach(row => {
              row.classList.remove('hide');
            });
          }
        </script>
      </body>
    </html
  HTML
end

def main
  if ARGV[0].nil?
    puts 'Usage: ruby generate_index.rb book_list_file_csv [output]'
    exit
  end

  booklist_csv = CSV.read(ARGV[0], headers: true)
  booklist_hash = booklist_csv.map do |line|
    {
      author: line['Author'],
      title: line['Book Title'],
      volumeNumber: line['Volume Number'],
      edition: line['Edition'],
      seriesTitle: line['Series Title'],
      subjectClassification: line['Subject Classification'],
      url: line['OpenURL'],
      doi: line['DOI URL']
    }
  end.sort_by do |item|
    item[:title]
  end

  output = ARGV[1] ? ARGV[1] : 'generated-index.html'
  File.write(output, template(booklist_hash.to_json))
end

main
