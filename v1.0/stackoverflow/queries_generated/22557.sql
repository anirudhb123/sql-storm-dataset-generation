WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5 AND (rp.UpVotes - rp.DownVotes) > 5
),
TagsWithExcerpts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        p.ExcerptPostId,
        CASE WHEN p.ExcerptPostId IS NOT NULL THEN (SELECT Title FROM Posts WHERE Id = p.ExcerptPostId) ELSE 'N/A' END AS ExcerptTitle
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.ExcerptPostId = p.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        STRING_AGG(c.Text, ' | ') AS CommentTexts,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.UpVotes,
        fp.DownVotes,
        tc.TagName,
        tc.ExcerptTitle,
        pc.CommentTexts,
        pc.TotalComments
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostLinks pl ON fp.PostId = pl.PostId
    LEFT JOIN 
        TagsWithExcerpts tc ON pl.RelatedPostId = tc.ExcerptPostId
    LEFT JOIN 
        PostComments pc ON fp.PostId = pc.PostId
    WHERE 
        tc.TagId IS NOT NULL OR pc.TotalComments > 0
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    COALESCE(fr.Score, 0) AS Score,
    fr.UpVotes,
    fr.DownVotes,
    COALESCE(fr.TagName, 'No Tags') AS TagName,
    COALESCE(fr.ExcerptTitle, 'No Excerpt') AS ExcerptTitle,
    COALESCE(fr.CommentTexts, 'No Comments') AS CommentTexts,
    fr.TotalComments
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.CreationDate ASC 
LIMIT 20;
