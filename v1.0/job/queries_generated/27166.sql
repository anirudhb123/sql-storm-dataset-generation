WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.imdb_id = pi.person_id
    GROUP BY 
        p.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    pd.name AS person_name,
    pd.personal_info,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    PersonDetails pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.title;

This SQL query starts by constructing two Common Table Expressions (CTEs) named `MovieDetails` and `PersonDetails`. The `MovieDetails` CTE aggregates relevant details about movies released between 2000 and 2023, including their title, production year, alternative names (aka_names), associated companies (company_names), and keywords. The `PersonDetails` CTE arranges personal information associated with each individual in the `name` table.

The final SELECT statement merges both CTEs based on the movie and person relationships, retrieving valuable information while ensuring efficient string processing to condense names, companies, and keywords into comma-separated lists. The result is ordered by production year, allowing for easy analysis of the most recent movies along with their associated individuals.
