WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT V.UserId) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Filtering for Questions only
    GROUP BY 
        P.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CreationDate,
        Score,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Select top 10 posts per tag
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        AVG(Score) AS AverageScore
    FROM 
        TopPosts
    GROUP BY 
        TagName
)
SELECT 
    T.TagName,
    T.PostCount,
    T.AverageScore,
    TP.Title,
    TP.Author,
    TP.CreationDate,
    TP.Score,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes
FROM 
    TagStatistics T
JOIN 
    TopPosts TP ON TP.Tags LIKE '%' || T.TagName || '%'
ORDER BY 
    T.TagName, TP.Score DESC;
