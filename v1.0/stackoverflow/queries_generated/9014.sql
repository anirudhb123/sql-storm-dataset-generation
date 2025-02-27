WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    u.DisplayName AS Author,
    u.Reputation,
    ISNULL(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostID IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = tp.PostID)
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = u.Id)
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
