WITH NameIndex AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        p.name AS person_name,
        ak.imdb_index AS aka_imdb_index,
        ak.md5sum AS aka_md5sum,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        r.role AS person_role,
        co.name AS company_name,
        co.country_code AS company_country,
        c.nr_order
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN keyword k ON t.id = k.id
    JOIN role_type r ON c.person_role_id = r.id
    JOIN movie_companies mc ON c.movie_id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    WHERE ak.name IS NOT NULL
),
KeywordCount AS (
    SELECT 
        aka_name,
        COUNT(movie_keyword) AS keyword_count
    FROM NameIndex
    GROUP BY aka_name
),
RankedMovies AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year,
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY aka_name ORDER BY keyword_count DESC) AS rank
    FROM NameIndex
    JOIN KeywordCount ON NameIndex.aka_name = KeywordCount.aka_name
)
SELECT 
    aka_name,
    STRING_AGG(DISTINCT movie_title || ' (' || production_year || ')', '; ') AS movies,
    MAX(keyword_count) AS max_keywords,
    MAX(rank) AS highest_rank
FROM RankedMovies
WHERE movie_title IS NOT NULL
GROUP BY aka_name
ORDER BY max_keywords DESC
LIMIT 10;
