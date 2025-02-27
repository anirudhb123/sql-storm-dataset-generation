WITH movie_rankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(AVG(ca.nr_order), 0) AS average_cast_order,
        COUNT(DISTINCT km.keyword) AS keyword_count
    FROM 
        aka_title t
        LEFT JOIN cast_info ca ON t.movie_id = ca.movie_id
        LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
        LEFT JOIN keyword km ON mk.keyword_id = km.id
    WHERE 
        t.production_year > 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind <> 'TV Movie')
    GROUP BY 
        t.id, t.title
),
highly_rated_movies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.average_cast_order,
        mr.keyword_count,
        RANK() OVER (ORDER BY mr.average_cast_order DESC) AS rank
    FROM 
        movie_rankings mr
    WHERE 
        mr.average_cast_order > (
            SELECT AVG(average_cast_order) FROM movie_rankings
        )
),
company_movie_data AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    hrm.movie_id,
    hrm.title,
    hrm.average_cast_order,
    hrm.keyword_count,
    cmd.companies,
    cmd.company_types
FROM 
    highly_rated_movies hrm
LEFT JOIN company_movie_data cmd ON hrm.movie_id = cmd.movie_id
WHERE 
    hrm.rank <= 10
ORDER BY 
    hrm.average_cast_order DESC,
    hrm.keyword_count DESC;

-- Leveraging window functions and complex joins alongside predicates that account for NULLs,
-- ensuring only significant movies with substantial cast presence and impressive keyword variety
-- are highlighted for examination.
