-- The following query retrieves a list of movies along with the main cast members,
-- filtering for a specific keyword and ordered by production year and actor name.
-- It also includes detailed information about the companies involved in the movie production.
SELECT
    t.title AS movie_title,
    t.production_year,
    ak.name AS actor_name,
    ct.kind AS company_type,
    cn.name AS company_name,
    ki.keyword AS movie_keyword
FROM
    title t
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    aka_name ak ON cc.subject_id = ak.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword ki ON mk.keyword_id = ki.id
WHERE
    ki.keyword ILIKE '%action%'  -- Example keyword filtering: adjust as needed
    AND ak.name IS NOT NULL
ORDER BY
    t.production_year DESC,
    ak.name ASC;
