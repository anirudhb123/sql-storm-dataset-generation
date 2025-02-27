
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.PostTypeId IN (1, 2)  
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        LastActivityDate, 
        Score, 
        ViewCount, 
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount, p.AnswerCount
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.LastActivityDate,
    trp.Score,
    trp.ViewCount,
    trp.AnswerCount,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes
FROM 
    TopRankedPosts trp
JOIN 
    PostVoteStats pvs ON trp.PostId = pvs.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
