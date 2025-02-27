WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_split ON TRUE
    LEFT JOIN 
        Tags t ON tag_split = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.AcceptedAnswerId, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Owner,
        rp.CommentCount,
        rp.AcceptedAnswerId,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.CommentCount DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.Owner,
    tp.CommentCount,
    CASE 
        WHEN tp.AcceptedAnswerId > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    tp.CreationDate
FROM 
    TopPosts tp
WHERE 
    tp.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY 
    tp.CommentCount DESC;
