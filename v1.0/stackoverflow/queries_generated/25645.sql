WITH PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        string_agg(distinct T.TagName, ', ') AS TagsList,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        unnest(string_to_array(P.Tags, ',')) AS TagName ON TRUE 
        LEFT JOIN 
        Tags T ON TRIM(TagName) = T.TagName
    WHERE 
        P.PostTypeId = 1  -- Filter for Questions only
    GROUP BY 
        P.Id, P.Title
),
AveragePostStats AS (
    SELECT 
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        AVG(BadgeCount) AS AvgBadges
    FROM 
        PostTagStats
),
TopPosts AS (
    SELECT 
        P.*,
        PS.TagsList,
        PS.CommentCount,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        CASE 
            WHEN PS.UpVotes - PS.DownVotes > 0 THEN 'Positive'
            WHEN PS.UpVotes - PS.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        PostTagStats PS
    JOIN 
        Posts P ON PS.PostId = P.Id
    ORDER BY 
        PS.VoteCount DESC, PS.CommentCount DESC
    LIMIT 10
)
SELECT 
    TOP 10
    P.Title,
    P.TagsList,
    P.CommentCount,
    P.VoteCount,
    P.UpVotes,
    P.DownVotes,
    P.Sentiment,
    A.AvgComments,
    A.AvgVotes,
    A.AvgUpVotes,
    A.AvgDownVotes,
    A.AvgBadges
FROM 
    TopPosts P,
    AveragePostStats A
ORDER BY 
    P.UpVotes DESC;
