WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Filtering for Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT posts.PostId) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        STRING_AGG(b.Name, ', ') AS Badges,
        MAX(rp.UserPostRank) AS HighestPostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts posts ON posts.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        RankedPosts rp ON rp.PostId = posts.Id
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBountyAmount,
    us.Badges,
    us.HighestPostRank,
    COUNT(DISTINCT rp.PostId) AS QuestionsAnswered,
    AVG(rp.Score) AS AvgQuestionScore,
    MAX(rp.ViewCount) AS MaxViewCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalBountyAmount, us.Badges, us.HighestPostRank
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;
