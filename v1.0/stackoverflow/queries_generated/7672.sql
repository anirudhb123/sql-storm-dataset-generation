WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), 'No Votes') AS LastVoteDate,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, ',')) AS tagName(tag) ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tagName.tag)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.LastVoteDate,
    rp.Tags,
    us.DisplayName AS OwnerName,
    us.Reputation AS OwnerReputation,
    us.PostCount AS OwnerPostCount,
    us.TotalScore AS OwnerTotalScore,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Rank
FROM 
    RankedPosts rp
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
