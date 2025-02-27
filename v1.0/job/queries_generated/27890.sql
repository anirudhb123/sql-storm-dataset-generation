WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name ASC) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1  -- Assuming 1 is for 'summary'
    WHERE t.production_year >= 2000  -- Filter for more recent films
    GROUP BY t.title, t.production_year, c.kind, mi.info
),
RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY md.production_year DESC) AS rank
    FROM MovieDetails md
)
SELECT 
    rank,
    movie_title,
    production_year,
    company_type,
    actors,
    keywords,
    movie_info
FROM RankedMovies
WHERE rank <= 10  -- Limit to top 10 most recent movies based on the rank
ORDER BY production_year DESC, rank;
