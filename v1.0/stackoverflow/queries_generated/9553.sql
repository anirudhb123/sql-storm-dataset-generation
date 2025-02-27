WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.ClosedDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS tag_name ON tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.OwnerReputation,
        pd.Score,
        pd.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerDisplayName ORDER BY pd.Score DESC) AS PostRank
    FROM 
        PostDetails pd
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tp.Score,
    tp.ViewCount
FROM 
    TopPosts tp
JOIN 
    UserBadges ub ON tp.OwnerDisplayName = ub.UserId
WHERE 
    tp.PostRank <= 5
ORDER BY 
    tp.OwnerDisplayName, tp.Score DESC;
