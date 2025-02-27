WITH RECURSIVE MovieHorrorCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_kind,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        c.kind = 'Horror'
),
KeywordCounts AS (
    SELECT
        movie_id,
        COUNT(*) AS keyword_count
    FROM
        MovieHorrorCTE
    GROUP BY
        movie_id
),
QualifiedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        kc.keyword_count,
        CASE 
            WHEN kc.keyword_count >= 3 THEN 'Highly Tagged'
            WHEN kc.keyword_count BETWEEN 1 AND 2 THEN 'Moderately Tagged'
            ELSE 'Not Tagged'
        END AS tagging_status
    FROM 
        MovieHorrorCTE mh
    JOIN 
        KeywordCounts kc ON mh.movie_id = kc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, kc.keyword_count
)

SELECT 
    qm.title,
    qm.production_year,
    qm.tagging_status,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            complete_cast cc
        WHERE 
            cc.movie_id = qm.movie_id
    ), 0) AS actor_count,
    (
        SELECT 
            STRING_AGG(DISTINCT ak.name, ', ') 
        FROM 
            cast_info ci
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id 
        WHERE 
            ci.movie_id = qm.movie_id
    ) AS actor_names
FROM 
    QualifiedMovies qm
ORDER BY 
    qm.production_year DESC, 
    qm.tagging_status;
