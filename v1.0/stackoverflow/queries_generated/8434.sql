WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(vt.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3)::int, 0) AS DownVotes,
        US.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN 
        Users US ON p.OwnerUserId = US.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, US.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*, 
        RANK() OVER (PARTITION BY RankScore ORDER BY RankViews) AS RankByViews
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.OwnerDisplayName,
    tp.RankScore,
    tp.RankByViews
FROM 
    TopPosts tp
WHERE 
    tp.RankScore <= 10 -- Top 10 posts by score
    AND tp.RankByViews <= 5 -- Top 5 posts by views within the top score bracket
ORDER BY 
    tp.RankScore, tp.RankByViews;
