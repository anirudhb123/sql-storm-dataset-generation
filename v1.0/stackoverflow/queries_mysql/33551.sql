
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS RankByScore,
        @prev_post_type_id := p.PostTypeId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_post_type_id := NULL) AS vars
    WHERE 
        p.PostTypeId IN (1, 2) 
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        @row_number_badges := IF(@prev_user_id = u.Id, @row_number_badges + 1, 1) AS BadgeRank,
        @prev_user_id := u.Id
    FROM 
        Users u, Badges b, (SELECT @row_number_badges := 0, @prev_user_id := NULL) AS vars
    WHERE 
        u.Id = b.UserId AND b.Class = 1 
    ORDER BY 
        u.Id, b.Date DESC
),
CommentStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    CASE 
        WHEN rs.UserId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasRecentGoldBadge,
    cs.CommentCount,
    cs.PositiveComments,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rs ON rp.PostId = rs.UserId AND rs.BadgeRank = 1
LEFT JOIN 
    CommentStatistics cs ON rp.PostId = cs.PostId
LEFT JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
WHERE 
    rp.RankByScore <= 10 
ORDER BY 
    rp.PostId;
