WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName
),
TopOwners AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS PostCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        OwnerDisplayName
),
FinalResult AS (
    SELECT 
        OwnerDisplayName,
        PostCount,
        TotalUpVotes,
        TotalComments,
        RANK() OVER (ORDER BY TotalUpVotes DESC, PostCount DESC) AS OwnerRank
    FROM 
        TopOwners
)
SELECT 
    OwnerDisplayName,
    PostCount,
    TotalUpVotes,
    TotalComments,
    OwnerRank
FROM 
    FinalResult
WHERE 
    OwnerRank <= 10
ORDER BY 
    OwnerRank;
