WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate, p.Title, p.Score, p.ViewCount
),
TopUserPosts AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        u.DisplayName,
        u.Reputation,
        u.Location,
        r.NumBadges
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS NumBadges
        FROM 
            Badges
        GROUP BY 
            UserId
    ) r ON u.Id = r.UserId
    WHERE 
        rp.UserPostRank <= 5 -- Top 5 recent posts per user
),
UserActivity AS (
    SELECT 
        ua.UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        ua.UserId
)
SELECT 
    up.Title,
    up.Score,
    up.ViewCount,
    up.DisplayName,
    up.Reputation,
    up.Location,
    COALESCE(ua.VoteCount, 0) AS TotalVotes,
    COALESCE(ua.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ua.DownVotes, 0) AS TotalDownVotes
FROM 
    TopUserPosts up
LEFT JOIN 
    UserActivity ua ON up.OwnerUserId = ua.UserId
ORDER BY 
    up.Reputation DESC, 
    up.Score DESC;

This complex query identifies the top 5 recent questions per user including their voting activity, and it incorporates several features like Common Table Expressions (CTEs), window functions, aggregate functions, and outer joins. The structure allows performance benchmarking on different user engagements and content quality, utilizing the complex relationships within the Schema.
