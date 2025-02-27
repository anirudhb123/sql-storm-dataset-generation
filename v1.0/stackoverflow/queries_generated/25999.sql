WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    JOIN 
        Posts pt ON pl.RelatedPostId = pt.Id
    WHERE 
        pt.PostTypeId = 1  -- only linked questions
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AuthorName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName AS PopularTag,
    pt.PostCount AS PopularTagPostCount,
    pt.TotalViewCount AS PopularTagTotalViewCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.PostId IN (
        SELECT pl.PostId
        FROM PostLinks pl
        WHERE pl.RelatedPostId = rp.PostId
    )
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.ViewCount DESC;
