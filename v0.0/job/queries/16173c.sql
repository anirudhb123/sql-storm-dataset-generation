SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.note IS NOT NULL AND mi.info > '"Hellboy: The Art of the Movie". Milwaukie, OR: Dark Horse Publishing, 2004, ISBN-10: 1593071884' AND k.phonetic_code IN ('C325', 'C426', 'D6162', 'E2526', 'G4152', 'G4341', 'J2616', 'S2621', 'V5161');