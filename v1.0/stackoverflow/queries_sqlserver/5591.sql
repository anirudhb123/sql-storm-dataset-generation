
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.*, 
        pt.Name AS PostTypeName, 
        ut.DisplayName AS OwnerName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = (SELECT TOP 1 PostTypeId FROM Posts WHERE Id = rp.PostId)
    JOIN 
        Users ut ON ut.Id = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.OwnerName,
    tp.PostTypeName
FROM 
    TopPosts tp
JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
WHERE 
    ph.CreationDate >= '2023-01-01' 
    AND ph.PostHistoryTypeId IN (10, 11)  
ORDER BY 
    tp.UpVotes DESC, 
    tp.ViewCount DESC;
