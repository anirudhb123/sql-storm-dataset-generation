WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(tv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(tv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(as.AnswerCount, 0) AS TotalAnswers,
    rp.Author,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot' 
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending' 
        ELSE 'Normal' 
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    TopVotes tv ON rp.PostId = tv.PostId
LEFT JOIN 
    AnswerStats as ON rp.PostId = as.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
