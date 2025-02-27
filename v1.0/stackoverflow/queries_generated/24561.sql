WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        SUM(COALESCE(b.Class, 0)) AS BadgesCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COALESCE(CAST(SUBSTRING(p.Body FROM '<p>(.*?)</p>') AS TEXT), '') AS BodySnippet,
        COALESCE(CONCAT_WS(', ', STUFF(p.Tags, 1, 1, ''), '...'), 'No Tags') AS Tags,
        COALESCE(DATEDIFF(DAY, p.CreationDate, GETDATE()), 0) AS DaysOld
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
TopUsers AS (
    SELECT
        u.UserId,
        u.DisplayName,
        u.Reputation,
        u.PostCount,
        u.UpvoteCount - u.DownvoteCount AS NetScore,
        CASE 
            WHEN u.Rank <= 5 THEN 'Top User'
            WHEN u.Rank <= 10 THEN 'Moderate User'
            ELSE 'Novice User'
        END AS UserCategory
    FROM 
        UserReputation u
    WHERE 
        u.PostCount > 10 AND u.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.NetScore,
    pd.PostId,
    pd.Title,
    pd.PostType,
    pd.BodySnippet,
    pd.Tags,
    pd.DaysOld,
    ROW_NUMBER() OVER (PARTITION BY tu.UserId ORDER BY pd.DaysOld DESC) AS RecentPostRank
FROM 
    TopUsers tu
LEFT JOIN 
    PostDetails pd ON pd.PostId IN (
        SELECT PostId 
        FROM Posts 
        WHERE OwnerUserId = tu.UserId 
        ORDER BY CreationDate DESC 
        OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
    )
WHERE 
    pd.Tags IS NOT NULL AND pd.DaysOld > 30 OR pd.BodySnippet ILIKE '%SQL%'
ORDER BY 
    tu.Reputation DESC, tu.NetScore DESC, pd.DaysOld DESC;
