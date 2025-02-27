WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
ActivityMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        ub.TotalBadges,
        pi.PostId,
        pi.Title,
        pi.OwnerDisplayName,
        pi.ViewCount,
        pi.Score,
        pi.Tags,
        am.TotalVotes,
        am.UpVotes,
        am.DownVotes
    FROM 
        UserBadges ub
    INNER JOIN 
        PostInfo pi ON pi.OwnerDisplayName = ub.DisplayName
    INNER JOIN 
        ActivityMetrics am ON pi.PostId = am.PostId
)
SELECT 
    *,
    (UpVotes - DownVotes) AS VoteBalance,
    (CASE 
         WHEN TotalBadges > 0 THEN 'Active User'
         ELSE 'New User'
     END) AS UserStatus
FROM 
    CombinedStats
ORDER BY 
    VoteBalance DESC,
    TotalBadges DESC,
    Score DESC
LIMIT 50;
