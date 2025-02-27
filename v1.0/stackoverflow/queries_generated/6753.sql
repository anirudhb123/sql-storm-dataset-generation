WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AuthorName,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    mau.DisplayName AS MostActiveUser,
    mau.PostCount,
    mau.TotalUpVotes,
    mau.TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    MostActiveUsers mau ON mau.UserId = rp.AuthorName
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
