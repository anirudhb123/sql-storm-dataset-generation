WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Start from movies produced after 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(c.person_id, 'No Cast') AS cast_person_id,
    COALESCE(c.role, 'No Role Assigned') AS role,
    COALESCE(cp.company_name, 'No Company') AS production_company,
    COALESCE(cp.company_type, 'Unknown Type') AS company_type,
    COALESCE(mg.keywords, 'No Keywords') AS keywords,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastWithRoles c ON mh.movie_id = c.movie_id
LEFT JOIN 
    CompanyDetails cp ON mh.movie_id = cp.movie_id
LEFT JOIN 
    MovieGenres mg ON mh.movie_id = mg.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.title, 
    mh.depth, 
    c.role_order;

### Explanation:
- **Recursive CTE (MovieHierarchy)**: This part generates a hierarchy of movies, starting with those produced after 2000. It recursively links movies through their relationships in the `movie_link` table.
  
- **CastWithRoles**: This CTE gathers the cast information along with their roles, giving a row number to each role within a movie for ordering.

- **CompanyDetails**: This gathers various companies associated with movies, retrieving both the company name and type, joining across the related tables.

- **MovieGenres**: This part collects the genres for each movie as a comma-separated string.

- **Final SELECT**: This retrieves data from all CTEs, using `LEFT JOIN` to ensure that if there are no roles, companies, or keywords associated with a movie, it still gets listed with a default value. The `ORDER BY` clause sorts the results appropriately.
