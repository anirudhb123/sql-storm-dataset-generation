WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Owner,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName
), PopularPosts AS (
    SELECT 
        PostId,
        Title,
        Owner,
        UpVotes,
        DownVotes,
        CommentCount,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 -- Most recent post from each user
)
SELECT 
    PP.Title,
    PP.Owner,
    PP.CommentCount,
    PP.NetVotes,
    CASE 
        WHEN PP.NetVotes > 0 THEN 'Popular'
        WHEN PP.NetVotes < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS PopularityStatus
FROM 
    PopularPosts PP
ORDER BY 
    PP.NetVotes DESC, PP.CommentCount DESC
LIMIT 10;
