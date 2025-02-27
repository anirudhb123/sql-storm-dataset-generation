WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        ak.name AS aka_name,
        p.gender,
        MIN(ci.nv_order) AS first_order,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN name p ON ak.person_id = p.imdb_id
    LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id AND cc.subject_id = ak.person_id
    GROUP BY p.id, ak.name, p.gender
    HAVING COUNT(DISTINCT ci.movie_id) > 1
),
Companies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        a.aka_name,
        a.gender,
        a.first_order,
        a.movie_count,
        c.company_name,
        c.company_type,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN rt.production_year > 2000 THEN 'Modern Era'
            WHEN rt.production_year BETWEEN 1980 AND 2000 THEN 'Late 20th Century'
            ELSE 'Classic'
        END AS movie_era
    FROM RankedMovies rt
    LEFT JOIN ActorDetails a ON rt.title_id = (
        SELECT ci.movie_id 
        FROM cast_info ci 
        WHERE ci.person_id IN (SELECT person_id FROM aka_name)
        ORDER BY ci.nr_order
        LIMIT 1
    )
    LEFT JOIN Companies c ON rt.title_id = c.movie_id
    LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.aka_name,
    md.gender,
    md.movie_era,
    md.movie_count,
    md.company_name,
    md.company_type,
    md.keywords
FROM MovieDetails md
WHERE md.gender IS NOT NULL AND md.movie_count > 2
ORDER BY md.production_year DESC, md.title;
