WITH ActorNames AS (
    SELECT
        ak.id AS aka_id,
        ak.name AS actor_name,
        p.gender AS actor_gender,
        ak.person_id
    FROM
        aka_name ak
    JOIN
        name p ON ak.person_id = p.imdb_id
    WHERE
        p.gender = 'F'  
),
MoviesWithNames AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ak.actor_name
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        ActorNames ak ON c.person_id = ak.person_id
    WHERE
        t.production_year >= 2000  
),
KeywordInfo AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        k.phonetic_code IS NOT NULL  
)
SELECT
    mw.movie_title,
    mw.production_year,
    STRING_AGG(DISTINCT mw.actor_name, ', ') AS co_stars,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
FROM
    MoviesWithNames mw
LEFT JOIN
    KeywordInfo ki ON mw.title_id = ki.movie_id
GROUP BY
    mw.movie_title, mw.production_year
ORDER BY
    mw.production_year DESC, mw.movie_title;