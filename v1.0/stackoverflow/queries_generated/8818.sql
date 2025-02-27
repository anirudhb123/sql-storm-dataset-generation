WITH RankedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Users.DisplayName AS Author,
        COUNT(Comments.Id) AS CommentCount,
        AVG(Votes.VoteTypeId = 2) AS UpvoteCount,  -- Upvotes
        AVG(Votes.VoteTypeId = 3) AS DownvoteCount, -- Downvotes
        ROW_NUMBER() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.Score DESC) AS UserPostRank
    FROM 
        Posts
    INNER JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Posts.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Posts.ViewCount, Users.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(Score) DESC) AS UserRank
    FROM 
        Posts
    WHERE 
        Posts.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.Author,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    TU.PostCount,
    TU.TotalScore,
    TU.UserRank
FROM 
    RankedPosts RP
JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.OwnerUserId
ORDER BY 
    TU.UserRank, RP.Score DESC, RP.CreationDate DESC
LIMIT 
    50;
