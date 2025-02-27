WITH RecursiveTagHierarchy AS (
    SELECT
        Tags.Id AS TagId,
        Tags.TagName,
        0 AS Level
    FROM
        Tags
    WHERE
        Tags.IsModeratorOnly = 0
    
    UNION ALL

    SELECT
        tl.RelatedPostId AS TagId,
        Tags.TagName,
        Level + 1
    FROM
        RecursiveTagHierarchy tl
    JOIN
        Posts p ON tl.TagId = p.Id
    JOIN
        PostLinks pl ON p.Id = pl.PostId
    JOIN
        Tags ON pl.RelatedPostId = Tags.Id
    WHERE
        tl.Level < 5
)

SELECT
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT t.TagName) AS UniqueTags,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(DATEDIFF(NOW(), p.CreationDate)) AS AvgPostAgeInDays,
    MAX(p.Score) AS HighestPostScore,
    COUNT(c.Id) AS TotalComments,
    CASE 
        WHEN COUNT(b.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    STRING_AGG(t.TagName, ', ') AS TagsList,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS Rnk
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 /* BountyStart */
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RecursiveTagHierarchy t ON p.Id = t.TagId
WHERE
    u.Reputation > 1000
GROUP BY
    u.Id, u.DisplayName
HAVING
    COUNT(DISTINCT t.TagName) > 5
ORDER BY
    TotalBounty DESC, UserId
LIMIT 100;

### Explanation:

- **Recursive CTE**: RecursiveTagHierarchy is created to retrieve tags associated with each post. This helps in analyzing user engagement with tags without excessive repetition.
- **Aggregate Functions**: The query aggregates user information, calculating sums, counts, and averages to benchmark user activity based on their contributions.
- **LEFT JOINs**: Used to connect multiple tables, allowing for detailed metrics on users, their posts, votes (specifically bounties), badges, comments, and tags.
- **COALESCE**: Utilized to handle any potential NULL values gracefully, ensuring that total bounties default to zero if no bounties exist.
- **CASE Statement**: Adds a user-friendly interpretation of whether a user has any badges.
- **STRING_AGG**: Aggregates the tag names into a single string, providing a quick overview of tags a user has engaged with.
- **Window Function**: ROW_NUMBER() identifies users' rank based on their total bounty contributions, allowing for prioritized results.
- **HAVING Clause**: Filters users to include only those with meaningful engagement (more than 5 unique tags).
- **ORDER BY and LIMIT**: Ensures we get the top 100 users according to total bounty amounts, providing a snapshot of highly engaged users in the community.
