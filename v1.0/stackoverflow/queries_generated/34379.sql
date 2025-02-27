WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Get only questions as root nodes

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        rp.Level + 1,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    INNER JOIN 
        Posts rp ON p.ParentId = rp.Id
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
    COALESCE(NULLIF(SUM(v.BountyAmount), 0), 0) AS TotalBounty,
    AVG(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AvgUpvotesPerQuestion,
    COUNT(DISTINCT bh.Id) AS TotalBadges,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Badges bh ON bh.UserId = u.Id
LEFT JOIN 
    PostTypes pt ON pt.Id = p.PostTypeId
WHERE 
    u.Reputation > 1000 
    AND u.CreationDate < NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    UserRank, TotalQuestions DESC;

This query performs the following operations:
1. A CTE (Common Table Expression) named `RecursivePosts` is used to gather all posts and their parent-child relationships for questions, allowing deeper analysis of threads.
2. The main SELECT pulls data from users who have a reputation greater than 1000 and who registered more than a year ago.
3. LEFT JOINs allow to aggregate information about the posts, accepted answers, votes, and badges associated with each user.
4. `COALESCE` and `NULLIF` functions deal with potential NULLs in bounty totals, ensuring we display 0 instead of NULL.
5. The `STRING_AGG` function aggregates the types of posts associated with each user.
6. The `RANK` function generates a ranking based on the total number of distinct questions asked by the users.
7. The `HAVING` clause filters the users to include only those who have asked more than 10 questions.
8. The final result set is ordered by rank and total question count for a structured and meaningful output.
