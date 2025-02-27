WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- UpVotes and DownVotes
    WHERE 
        p.PostTypeId IN (1, 2) -- Consider only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 -- Only take the most recent version of each post
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    pt.TagName
FROM 
    TopPosts tp
JOIN 
    PopularTags pt ON tp.Title LIKE '%' || pt.TagName || '%'
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
