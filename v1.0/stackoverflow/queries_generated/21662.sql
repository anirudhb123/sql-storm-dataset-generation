WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate) AS RowNum
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.Views, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC, TotalBounty DESC) AS Rank
    FROM 
        RecursiveUserStats
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int[])) ) AS AllTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.AcceptedAnswerId IS NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        TotalCommentScore,
        CommentCount,
        AllTags,
        COUNT(*) OVER () AS TotalPostsLastYear
    FROM 
        PostActivity
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    psa.PostId,
    psa.Title,
    psa.CreationDate,
    psa.Score,
    psa.ViewCount,
    psa.TotalCommentScore,
    psa.CommentCount,
    psa.AllTags,
    CASE 
        WHEN psa.CommentCount > 10 THEN 'Highly Engaged'
        WHEN psa.CommentCount BETWEEN 1 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN tu.Reputation IS NULL THEN 'No Data'
        ELSE 
            CASE 
                WHEN tu.Reputation > 1000 THEN 'Experienced User'
                ELSE 'New User'
            END
    END AS UserType
FROM 
    TopUsers tu
LEFT JOIN 
    PostStatistics psa ON tu.UserId = psa.PostId
WHERE 
    tu.Rank < 20 -- Get top 20 users based on rank
ORDER BY 
    tu.Reputation DESC, psa.Score DESC;

-- Adding an unusual NULL logic condition with parameters
SELECT 
    u.DisplayName,
    COALESCE(pa.total, 'No Posts') AS PostCountOrMessage
FROM 
    Users u
LEFT JOIN 
    (SELECT OwnerUserId, COUNT(*) as total 
     FROM Posts 
     GROUP BY OwnerUserId) pa ON pa.OwnerUserId = u.Id
WHERE 
    u.Location IS NOT NULL 
    AND u.AboutMe IS NOT NULL;
