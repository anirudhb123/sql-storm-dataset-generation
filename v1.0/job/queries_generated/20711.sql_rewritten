WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        CASE 
            WHEN t.season_nr IS NOT NULL THEN 'Episode'
            ELSE 'Movie'
        END AS title_type
    FROM title t
    WHERE t.production_year > 2000

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.imdb_index,
        'Unknown' 
    FROM title t
    WHERE NOT EXISTS (SELECT 1 FROM title t2 WHERE t2.id = t.id AND t2.production_year > 2000)
),

FilteredMovieKeyword AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
),

AggregatedCompany AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(CASE WHEN c.name IS NULL THEN 'Unknown Company' ELSE c.name END, ', ') AS companies
    FROM movie_companies mc
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),

CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS total_cast,
        COUNT(DISTINCT ci.person_id) AS distinct_actors
    FROM cast_info ci
    GROUP BY ci.movie_id
),

FinalOutput AS (
    SELECT 
        tt.title,
        tt.production_year,
        tt.title_type,
        mk.keyword,
        ac.companies,
        cs.total_cast,
        cs.distinct_actors,
        ROW_NUMBER() OVER (PARTITION BY tt.production_year ORDER BY cs.total_cast DESC) AS rank_by_cast,
        DENSE_RANK() OVER (ORDER BY tt.production_year) AS rank_by_year
    FROM RecursiveTitle tt
    LEFT JOIN FilteredMovieKeyword mk ON tt.title_id = mk.movie_id
    LEFT JOIN AggregatedCompany ac ON tt.title_id = ac.movie_id
    LEFT JOIN CastStatistics cs ON tt.title_id = cs.movie_id
)

SELECT 
    title,
    production_year,
    title_type,
    COALESCE(keyword, 'No Keywords') AS keyword,
    companies,
    total_cast,
    distinct_actors,
    rank_by_cast,
    rank_by_year
FROM FinalOutput
WHERE rank_by_cast <= 5
ORDER BY production_year DESC, total_cast DESC;