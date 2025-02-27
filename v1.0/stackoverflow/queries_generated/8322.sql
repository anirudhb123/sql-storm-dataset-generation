WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        AVG(v.BountyAmount) AS AverageBounty,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        AverageBounty
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.AverageBounty,
    COALESCE(pht.CreationDate, 'No Edits') AS LastEditDate,
    COUNT(c.Id) AS CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory pht ON tp.PostId = pht.PostId AND pht.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.AnswerCount, tp.AverageBounty, pht.CreationDate
ORDER BY 
    tp.AnswerCount DESC, tp.Title;
