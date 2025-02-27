WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        COALESCE(cm.name, 'Unknown Company') AS company_name,
        t.production_year,
        RANK() OVER (PARTITION BY t.year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = t.id
    GROUP BY
        t.id, t.title, cm.name, t.production_year
),
FoundKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT 
    rm.title,
    rm.company_name,
    rm.production_year,
    COALESCE(fk.keywords, 'No Keywords') AS keywords,
    COALESCE((SELECT ARRAY_AGG(DISTINCT ai.name ORDER BY ai.name) 
               FROM aka_name ai 
               WHERE ai.person_id IN 
                   (SELECT c.person_id 
                    FROM cast_info c 
                    WHERE c.movie_id = rm.movie_id)), 
               'No Actors') AS actor_names,
    (SELECT COUNT(*) 
     FROM movie_link ml 
     WHERE ml.movie_id = rm.movie_id 
     AND ml.linked_movie_id IS NULL) AS unlinked_count
FROM 
    RankedMovies rm
LEFT JOIN 
    FoundKeywords fk ON rm.movie_id = fk.movie_id
WHERE 
    rm.rank_by_cast <= 5 
    AND rm.company_name NOT LIKE '%test%'
    AND (rm.production_year IS NULL OR rm.production_year >= 2000)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_cast
LIMIT 10 OFFSET 5;
