
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        ROW_NUMBER() OVER(PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        kind_type AS kt ON t.kind_id = kt.id
    WHERE 
        kt.kind LIKE 'movie%'
),
PopularActors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info AS ca
    JOIN 
        aka_name AS ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id, ak.name
    HAVING 
        COUNT(DISTINCT ca.person_id) > 1
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    pa.actor_name,
    mk.keywords
FROM 
    RankedTitles AS rt
LEFT JOIN 
    PopularActors AS pa ON rt.title_id = pa.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON rt.title_id = mk.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC,
    rt.title;
