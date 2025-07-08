
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
        JOIN complete_cast cc ON t.id = cc.movie_id
        JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
MostActiveActors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ct.movie_id) AS movies_count
    FROM 
        aka_name ka
        JOIN cast_info ct ON ka.person_id = ct.person_id
    WHERE 
        ka.name LIKE '%Smith%'
    GROUP BY 
        ka.person_id, ka.name
    ORDER BY 
        movies_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        kc.keyword,
        mt.kind_id
    FROM 
        aka_title mt
        JOIN movie_keyword mk ON mt.id = mk.movie_id
        JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year >= 2000 
)
SELECT 
    rd.title_id,
    rd.title,
    rd.production_year,
    ra.name AS actor_name,
    rd.cast_count,
    ARRAY_AGG(DISTINCT md.keyword) AS keywords
FROM 
    RankedTitles rd
    JOIN MostActiveActors ra ON ra.movies_count > rd.cast_count
    JOIN MovieDetails md ON md.movie_id = rd.title_id
GROUP BY 
    rd.title_id, rd.title, rd.production_year, ra.name, rd.cast_count
ORDER BY 
    rd.production_year DESC, rd.cast_count DESC;
