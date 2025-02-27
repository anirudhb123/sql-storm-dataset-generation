WITH RecursiveTagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = Posts.Id
    WHERE 
        Posts.PostTypeId = 1  -- Only considering Questions
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        RecursiveTagCounts
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionsAnswered,
        SUM(Comments.Score) AS CommentScore,
        COUNT(DISTINCT Badges.Id) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId AND Posts.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),
PopularAnswers AS (
    SELECT 
        P.Id AS AnswerId, 
        P.OwnerUserId AS UserId,
        P.Score AS AnswerScore,
        P.CreationDate,
        P.Title,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  -- Only Upvotes
    WHERE 
        P.PostTypeId = 2 AND P.Score > 0  -- Only valid Answers
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.CreationDate, P.Title
)
SELECT 
    U.DisplayName AS UserName,
    U.QuestionsAnswered,
    U.CommentScore,
    U.BadgeCount,
    T.TagName,
    T.PostCount,
    A.AnswerId,
    A.Title AS AnswerTitle,
    A.AnswerScore,
    A.VoteCount
FROM 
    UserActivity U
JOIN 
    TopTags T ON U.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE PostTypeId = 1
    )
LEFT JOIN 
    PopularAnswers A ON U.UserId = A.UserId
WHERE 
    T.TagRank <= 10  -- Top 10 tags
ORDER BY 
    U.CommentScore DESC, A.VoteCount DESC;
