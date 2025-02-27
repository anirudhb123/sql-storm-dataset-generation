WITH UserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.Id) AS TagCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT c.Text, ' | ') AS Comments,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') -- Filtering posts from the last year
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    ORDER BY 
        p.Score DESC, VoteCount DESC
    LIMIT 10 -- Selecting top 10 posts by score and votes
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ut.TagCount,
        ut.Tags,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        UserTags ut ON u.Id = ut.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, ut.TagCount, ut.Tags
    ORDER BY 
        u.Reputation DESC
    LIMIT 5 -- Selecting top 5 users by reputation
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.TagCount,
    tu.Tags,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViews,
    pp.Score AS PopularPostScore,
    pp.Comments AS PopularPostComments,
    tu.TotalViews
FROM 
    TopUsers tu
JOIN 
    PopularPosts pp ON tu.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = pp.PostId)
ORDER BY 
    tu.Reputation DESC, pp.Score DESC;
