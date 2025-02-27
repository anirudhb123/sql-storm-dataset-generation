WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pm.*,
        ROW_NUMBER() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS OverallRank
    FROM 
        PostMetrics pm
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    u.DisplayName,
    us.AvgReputation,
    CASE 
        WHEN rp.UserPostRank <= 5 THEN 'Top Poster'
        ELSE 'Regular Poster'
    END AS UserCategory
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    rp.OverallRank <= 50
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
