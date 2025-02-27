WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Posts pa
            WHERE pa.ParentId = p.Id
        ), 0) AS AnswerCount,
        COALESCE((SELECT SUM(vt.BountyAmount)
                  FROM Votes v
                  INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
                  WHERE v.PostId = p.Id AND vt.Name = 'BountyClose'), 0) AS TotalBounty
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),

TagDetails AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),

ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(pt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
    GROUP BY 
        ph.PostId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.Author,
    pa.CreationDate,
    pa.ViewCount,
    pa.CommentCount,
    pa.AnswerCount,
    pa.TotalBounty,
    td.TagName,
    td.TagUsageCount,
    cpf.LastClosedDate,
    cpf.CloseReasons
FROM 
    PostAnalytics pa
LEFT JOIN 
    TagDetails td ON pa.PostId = td.TagName
LEFT JOIN 
    ClosedPostDetails cpf ON pa.PostId = cpf.PostId
ORDER BY 
    pa.ViewCount DESC, 
    pa.CreationDate DESC
LIMIT 50;
