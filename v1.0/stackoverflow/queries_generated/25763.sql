WITH UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVoteCount, -- Upvotes
        SUM(v.VoteTypeId = 3) AS DownVoteCount -- Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputationStats
)
SELECT 
    pu.DisplayName AS PopularUser,
    pu.Reputation,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    pp.AnswerCount AS PopularPostAnswers,
    pp.Tags AS PopularPostTags
FROM 
    PopularPosts pp
JOIN 
    Posts p ON p.Id = pp.PostId
JOIN 
    TopUsers pu ON p.OwnerUserId = pu.UserId
WHERE 
    pu.ReputationRank <= 10 -- Top 10 users by reputation
ORDER BY 
    pu.Reputation DESC, pp.ViewCount DESC;
