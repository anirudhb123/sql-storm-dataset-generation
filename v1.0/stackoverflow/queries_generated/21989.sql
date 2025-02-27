WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(p.ClosedDate, '9999-12-31'::timestamp) AS ClosedOrDefault
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Only counting bounty start and close votes
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ClosedDate
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastModification
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),
ClosedPostDetails AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.CommentCount,
        r.TotalBounty,
        r.ClosedOrDefault,
        phs.HistoryTypes,
        phs.LastModification
    FROM 
        RankedPosts r
    JOIN 
        PostHistorySummary phs ON r.PostId = phs.PostId
    WHERE 
        r.ClosedOrDefault < '9999-12-31'::timestamp  -- Identify closed posts
)

SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.CommentCount,
    p.TotalBounty,
    p.HistoryTypes,
    p.LastModification,
    CASE 
        WHEN p.CommentCount > 10 THEN 'Highly Discussed'
        WHEN p.TotalBounty > 0 THEN 'Bounty Offered'
        ELSE 'Regular Post'
    END AS PostCategory,
    (SELECT COUNT(*) 
     FROM Posts sub_p 
     WHERE sub_p.ParentId = p.PostId) AS RelatedAnswersCount,
    (SELECT STRING_AGG(Tags.TagName, ', ')
     FROM Tags 
     JOIN STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_names ON Tags.TagName = tag_names) AS PostTags
FROM 
    ClosedPostDetails p
ORDER BY 
    p.LastModification DESC
LIMIT 50 OFFSET 0;  -- Implement pagination

