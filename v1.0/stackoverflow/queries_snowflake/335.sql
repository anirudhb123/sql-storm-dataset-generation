
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.UpVoteCount DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    r.PostId,
    r.Title,
    r.PostTypeId,
    r.CommentCount,
    r.UpVoteCount,
    r.DownVoteCount,
    CASE 
        WHEN r.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS RankCategory,
    (SELECT LISTAGG(DISTINCT t.TagName, ',') 
     FROM Tags t 
     JOIN LATERAL FLATTEN(INPUT => SPLIT(p.Tags, ',')) AS tag ON t.TagName = tag.VALUE
     WHERE p.Id = r.PostId) AS Tags
FROM 
    RankedPosts r
LEFT JOIN 
    Posts p ON r.PostId = p.Id
WHERE 
    r.Rank <= 10 OR r.PostTypeId IN (1, 2)
ORDER BY 
    r.UpVoteCount DESC NULLS LAST;
