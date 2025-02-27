WITH RecursiveTopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursiveTopPosts rp ON rp.PostId = p.ParentId
)

SELECT 
    pt.Name AS PostType,
    u.DisplayName AS UserName,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(p.Score) AS AverageScore,
    SUM(CASE 
        WHEN bh.Class = 1 THEN 1 
        ELSE 0 
    END) AS GoldBadges,
    SUM(CASE 
        WHEN bh.Class = 2 THEN 1 
        ELSE 0 
    END) AS SilverBadges,
    SUM(CASE 
        WHEN bh.Class = 3 THEN 1 
        ELSE 0 
    END) AS BronzeBadges,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags
FROM 
    RecursiveTopPosts rtp
LEFT JOIN 
    Posts p ON rtp.PostId = p.Id
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    Tags tg ON tg.ExcerptPostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    pt.Name, u.DisplayName
ORDER BY 
    AverageScore DESC,
    TotalVotes DESC
LIMIT 10;

### Explanation:
1. **Recursive CTE (`RecursiveTopPosts`)**: This CTE finds the hierarchy of questions and their answers, starting from questions (PostTypeId = 1). It recursively retrieves posts linked as answers based on ParentId.
   
2. **Main Query**:
    - Selects relevant information about the post type and user.
    - Uses `COUNT` to tally the total votes and comments.
    - Calculates the average score for the posts.
    - Sums the number of badges received by users, categorized by gold, silver, and bronze.
    - Aggregates the associated tags for each post into a single string using `STRING_AGG`.
    
3. **Joins**: 
    - Connects various tables such as `Posts`, `PostTypes`, `Users`, `Votes`, `Comments`, `Badges`, and `Tags` to retrieve comprehensive data.
    
4. **Filtering and Sorting**: 
    - Filters posts created within the last year.
    - Groups by post type and user name, with results sorted first by average score and then by total votes.
    
5. **Limiting Result**: Limits the output to the top 10 entries based on the sorting criteria.
