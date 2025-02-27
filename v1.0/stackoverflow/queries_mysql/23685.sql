
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        @rownum := IF(@prev_post_type = p.PostTypeId, @rownum + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        GROUP_CONCAT(DISTINCT tag.TagName) AS Tags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 
                (SELECT COUNT(*) 
                 FROM Votes v 
                 WHERE v.PostId = p.AcceptedAnswerId AND v.VoteTypeId = 2) 
            ELSE 0 
        END AS UpvotesOnAcceptedAnswer
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN (
            SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
            FROM (
                SELECT @rownum := 0
            ) r
            CROSS JOIN (
                SELECT a.N + b.N * 10 + 1 n
                FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
            ) n
            WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
        ) tag ON TRUE
    CROSS JOIN (SELECT @prev_post_type := NULL, @rownum := 0) r
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId
),
PostInteraction AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        RankedPosts rp
        INNER JOIN Users u ON u.Id = rp.OwnerUserId
        LEFT JOIN (
            SELECT 
                UserId, 
                MAX(Class) AS Class 
            FROM 
                Badges 
            WHERE 
                Date >= '2023-10-01 12:34:56'
            GROUP BY 
                UserId
        ) b ON b.UserId = u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        @vote_rank := IF(@prev_vote_post = v.PostId AND @prev_vote_user = v.UserId, @vote_rank + 1, 1) AS VoteRank,
        @prev_vote_post := v.PostId,
        @prev_vote_user := v.UserId
    FROM 
        Votes v
    CROSS JOIN (SELECT @prev_vote_post := NULL, @prev_vote_user := NULL, @vote_rank := 0) r
    WHERE 
        v.CreationDate >= '2023-10-01 12:34:56'
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.ViewCount,
    pi.CommentCount,
    pi.OwnerDisplayName,
    pi.Reputation,
    pi.BadgeClass,
    pi.Tags,
    pi.UpvotesOnAcceptedAnswer,
    COALESCE(rv.VoteTypeId, 0) AS LastVoteType,
    CASE 
        WHEN pi.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostInteraction pi
    LEFT JOIN RecentVotes rv ON rv.PostId = pi.PostId AND rv.VoteRank = 1
WHERE 
    pi.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
    AND pi.Score > 0 
    AND (pi.BadgeClass IS NULL OR pi.BadgeClass < 3) 
ORDER BY 
    pi.Rank, 
    pi.CreationDate DESC
LIMIT 50;
