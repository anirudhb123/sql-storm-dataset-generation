
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT t.TagName) AS TagCount,
        LISTAGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t(TagName) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
),
PostScores AS (
    SELECT 
        p.Id,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(ph.Comment, '') AS LastEditComment
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Score, ph.Comment
),
RankedPosts AS (
    SELECT 
        pt.PostId,
        pt.Title,
        pt.TagCount,
        pt.TagsList,
        ps.Score,
        ps.TotalBounty,
        ps.LastEditComment,
        ROW_NUMBER() OVER (ORDER BY pt.TagCount DESC, ps.Score DESC) AS Rank
    FROM 
        PostTagCounts pt
    JOIN 
        PostScores ps ON pt.PostId = ps.Id
)
SELECT 
    r.Rank,
    r.Title,
    r.TagCount,
    r.TagsList,
    r.Score,
    r.TotalBounty,
    r.LastEditComment
FROM 
    RankedPosts r
WHERE 
    r.TagCount > 0
ORDER BY 
    r.Rank;
