
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount 
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        CloseCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1 
)
SELECT
    P.PostId,
    P.Title,
    DATALENGTH(P.Body) AS BodyLength,
    LEN(P.Tags) - LEN(REPLACE(P.Tags, '>', '')) + 1 AS TagCount,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    P.CloseCount,
    CASE 
        WHEN P.UpVotes - P.DownVotes > 0 THEN 'Positive' 
        WHEN P.UpVotes - P.DownVotes < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Sentiment,
    P.OwnerDisplayName,
    P.CreationDate
FROM 
    FilteredPosts P
ORDER BY 
    P.UpVotes DESC, P.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
