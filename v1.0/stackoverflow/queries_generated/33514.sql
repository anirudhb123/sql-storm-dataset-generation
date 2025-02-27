WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year') 
        AND p.Score > 0
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),

PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_TO_ARRAY(p.Tags, '>') AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(tag) 
    GROUP BY 
        p.Id
)

SELECT 
    q.PostId,
    q.Title,
    q.Score,
    q.OwnerDisplayName,
    vc.VoteCount,
    vc.UpVotes,
    vc.DownVotes,
    pt.Tags
FROM 
    TopQuestions q
LEFT JOIN 
    PostVoteCounts vc ON q.PostId = vc.PostId
LEFT JOIN 
    PostTags pt ON q.PostId = pt.PostId
ORDER BY 
    q.Score DESC;

-- Recursive CTE for related posts to display in a hierarchical manner if needed
WITH RECURSIVE RelatedPosts AS (
    SELECT 
        pl.RelatedPostId,
        pl.PostId,
        1 AS Level
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId IN (SELECT PostId FROM TopQuestions)
    
    UNION ALL
    
    SELECT 
        pl.RelatedPostId,
        rp.PostId,
        rp.Level + 1
    FROM 
        PostLinks pl
    JOIN 
        RelatedPosts rp ON pl.PostId = rp.RelatedPostId
)
SELECT 
    rp.PostId,
    COUNT(rp.RelatedPostId) AS RelatedPostCount
FROM 
    RelatedPosts rp
GROUP BY 
    rp.PostId;
