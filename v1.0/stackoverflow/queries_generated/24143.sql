WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(v.UpVotes - v.DownVotes, 0) AS NetVotes,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankInType
    FROM 
        Posts p 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            ParentId, COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 -- Answers
        GROUP BY 
            ParentId) a ON a.ParentId = p.Id
    LEFT JOIN 
        (SELECT 
            PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
        FROM 
            Votes 
        GROUP BY 
            PostId) v ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id::text = ph.Comment 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.NetVotes,
    cp.FirstClosedDate,
    cp.CloseReasons
FROM 
    RankedPosts rp 
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    (rp.RankInType = 1 OR (cp.FirstClosedDate IS NOT NULL AND cp.FirstClosedDate < NOW() - INTERVAL '6 months'))
ORDER BY 
    rp.NetVotes DESC, 
    rp.CreationDate ASC
LIMIT 100;

-- Performing a self-join to identify posts with similar tags, along with their edit history to capture the evolution of content over time.
WITH TagHistories AS (
    SELECT 
        p.Id AS PostId,
        TH.CreationDate,
        TH.UserDisplayName,
        TH.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY TH.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory TH ON p.Id = TH.PostId 
    WHERE 
        TH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    UNION ALL
    SELECT 
        p.Id,
        p.CreationDate,
        u.DisplayName AS UserDisplayName,
        'Initial Post Created' AS EditComment,
        1 AS EditRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    p1.PostId,
    p1.Title,
    p2.Title AS SimilarPostTitle,
    (SELECT COUNT(*) FROM Tags t WHERE t.Id = ANY(string_to_array(substring(p1.Tags, 2, length(p1.Tags) - 2), '><')::int[])) AS SharedTagCount,
    th.CreationDate AS LastEditDate,
    th.UserDisplayName AS LastEditedBy,
    th.EditComment
FROM 
    Posts p1
JOIN 
    Posts p2 ON p1.Id <> p2.Id AND p1.Tags && p2.Tags -- Overlap in tags
LEFT JOIN 
    TagHistories th ON p1.Id = th.PostId AND th.EditRank = 1
WHERE 
    th.LastEditDate >= NOW() - INTERVAL '2 months'
ORDER BY 
    SharedTagCount DESC, 
    th.LastEditDate DESC;

-- Final selection of posts that have at least one comment, to ensure interaction context
SELECT 
    rp.* 
FROM 
    RankedPosts rp 
JOIN 
    Comments c ON c.PostId = rp.PostId
WHERE 
    rp.NetVotes > 0
ORDER BY 
    rp.NetVotes DESC, 
    rp.CreationDate ASC;
