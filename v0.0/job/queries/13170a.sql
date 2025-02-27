SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title IN ('Hang the Law', 'Lippstixxx & Dippstixxx', 'Loose Change', 'Oh, Simone', 'Run for Your Ed', 'Second Half Preliminary Round 5: Yao vs. Granger/Ramsey vs. Traylor', 'Vocación, equivocación', 'Wochenfinale #2') AND mi.note < '(exteriors: Los Angeles City Hall)';