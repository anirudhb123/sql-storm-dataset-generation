
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE((
            SELECT 
                LISTAGG(c.Text, ' | ') 
            FROM 
                Comments c 
            WHERE 
                c.PostId = p.Id
        ), 'No comments') AS Comments,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, p.CreationDate
),

StringProcessed AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Comments,
        rp.VoteCount,
        rp.BadgeCount,
        INITCAP(SUBSTR(rp.Body, 1, 200)) AS Snippet, 
        REPLACE(rp.Tags, '<', '') AS CleanedTags 
    FROM 
        RankedPosts rp
)

SELECT 
    sp.PostId,
    sp.Title,
    sp.Snippet,
    sp.Comments,
    sp.VoteCount,
    sp.BadgeCount,
    CASE 
        WHEN sp.VoteCount > 10 THEN 'Popular'
        WHEN sp.VoteCount BETWEEN 1 AND 10 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS Popularity,
    LISTAGG(DISTINCT sp.CleanedTags, ', ') AS UniqueTags
FROM 
    StringProcessed sp
GROUP BY 
    sp.PostId, sp.Title, sp.Snippet, sp.Comments, sp.VoteCount, sp.BadgeCount
ORDER BY 
    sp.VoteCount DESC, sp.BadgeCount DESC;
